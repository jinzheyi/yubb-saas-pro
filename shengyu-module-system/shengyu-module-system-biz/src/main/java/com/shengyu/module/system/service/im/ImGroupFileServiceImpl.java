package com.shengyu.module.system.service.im;

import cn.hutool.core.io.IoUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.infra.api.file.FileApi;
import com.shengyu.module.infra.api.file.dto.FileDTO;
import com.shengyu.module.system.controller.app.im.vo.file.AppImGroupFilePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.file.AppImGroupFileRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupFileDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImGroupFileMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import java.util.List;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 群文件 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImGroupFileServiceImpl implements ImGroupFileService {

    @Resource
    private ImGroupFileMapper groupFileMapper;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private FileApi fileApi;  // ✅ 正确：通过 API 接口调用

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupFileRespVO uploadFile(Long userId, Long groupId, MultipartFile file) throws Exception {
        // 1. 验证权限：用户必须是群成员
        validateGroupMember(groupId, userId);
        
        // 2. 通过 FileApi 上传文件，获取文件 ID
        String directory = "im/group/" + groupId;
        byte[] content = IoUtil.readBytes(file.getInputStream());
        Long fileId = fileApi.createFileAndReturnId(
            content, 
            file.getOriginalFilename(), 
            directory, 
            file.getContentType()
        );
        
        if (fileId == null) {
            throw exception(GROUP_FILE_NOT_EXISTS);
        }
        
        // 3. 创建群文件关联记录
        ImGroupFileDO groupFile = ImGroupFileDO.builder()
                .groupId(groupId)
                .fileId(fileId)
                .uploaderId(userId)
                .folderId(0L)
                .isFavorite(false)
                .downloadCount(0)
                .build();
        
        groupFileMapper.insert(groupFile);
        
        log.info("[ImGroupFileService] 上传群文件成功, groupId: {}, userId: {}, fileId: {}, fileName: {}", 
                groupId, userId, fileId, file.getOriginalFilename());
        
        // 4. 返回文件信息
        return convertToRespVO(groupFile);
    }

    @Override
    public PageResult<AppImGroupFileRespVO> getFileList(AppImGroupFilePageReqVO pageReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 1. 验证权限：用户必须是群成员
        validateGroupMember(pageReqVO.getGroupId(), userId);
        
        // 2. 构建查询条件
        LambdaQueryWrapper<ImGroupFileDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImGroupFileDO::getGroupId, pageReqVO.getGroupId());
        
        // 3. 排序：按创建时间倒序
        wrapper.orderByDesc(ImGroupFileDO::getCreateTime);
        
        // 4. 分页查询
        Page<ImGroupFileDO> page = groupFileMapper.selectPage(
                new Page<>(pageReqVO.getPageNo(), pageReqVO.getPageSize()),
                wrapper
        );
        
        // 5. 转换为 VO（关联查询文件信息）
        List<AppImGroupFileRespVO> list = page.getRecords().stream()
                .map(this::convertToRespVO)
                .collect(Collectors.toList());
        
        // 6. 如果有文件名搜索或类型过滤，在内存中过滤
        if (pageReqVO.getFileName() != null && !pageReqVO.getFileName().isEmpty()) {
            String keyword = pageReqVO.getFileName().toLowerCase();
            list = list.stream()
                    .filter(vo -> vo.getFileName() != null && vo.getFileName().toLowerCase().contains(keyword))
                    .collect(Collectors.toList());
        }
        
        if (pageReqVO.getFileType() != null && !pageReqVO.getFileType().isEmpty()) {
            list = list.stream()
                    .filter(vo -> matchFileType(vo.getFileName(), pageReqVO.getFileType()))
                    .collect(Collectors.toList());
        }
        
        return new PageResult<>(list, page.getTotal());
    }
    
    /**
     * 判断文件类型是否匹配
     */
    private boolean matchFileType(String fileName, String fileType) {
        if (fileName == null) return false;
        
        String ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
        
        switch (fileType) {
            case "image":
                return ext.matches("jpg|jpeg|png|gif|bmp|webp");
            case "video":
                return ext.matches("mp4|avi|mov|wmv|flv|mkv");
            case "file":
                return !ext.matches("jpg|jpeg|png|gif|bmp|webp|mp4|avi|mov|wmv|flv|mkv");
            default:
                return true;
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteFile(Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 1. 查询文件
        ImGroupFileDO groupFile = groupFileMapper.selectById(id);
        if (groupFile == null) {
            throw exception(GROUP_FILE_NOT_EXISTS);
        }
        
        // 2. 验证删除权限（上传者或群主）
        validateDeletePermission(groupFile, userId);
        
        // 3. 删除文件关联记录（逻辑删除）
        groupFileMapper.deleteById(id);
        
        // 注意：这里不删除 infra_file 中的实际文件，因为可能被其他地方引用
        
        log.info("[ImGroupFileService] 删除群文件成功, id: {}, userId: {}", id, userId);
    }

    @Override
    public void incrementDownloadCount(Long id) {
        ImGroupFileDO groupFile = groupFileMapper.selectById(id);
        if (groupFile == null) {
            return;
        }
        
        // 增加下载次数
        groupFile.setDownloadCount(groupFile.getDownloadCount() + 1);
        groupFileMapper.updateById(groupFile);
    }

    // ========== 私有方法 ==========

    /**
     * 验证用户是否为群成员
     */
    private void validateGroupMember(Long groupId, Long userId) {
        ImGroupUserDO groupUser = groupUserMapper.selectOne(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
                        .eq(ImGroupUserDO::getUserId, userId)
                        .eq(ImGroupUserDO::getDeleted, false)
        );
        
        if (groupUser == null) {
            throw exception(NOT_GROUP_MEMBER);
        }
    }

    /**
     * 验证删除权限（上传者或群主）
     */
    private void validateDeletePermission(ImGroupFileDO groupFile, Long userId) {
        // 上传者可以删除
        if (groupFile.getUploaderId().equals(userId)) {
            return;
        }
        
        // 检查是否为群主
        ImGroupUserDO groupUser = groupUserMapper.selectOne(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupFile.getGroupId())
                        .eq(ImGroupUserDO::getUserId, userId)
                        .eq(ImGroupUserDO::getRole, 2)  // 2-群主
                        .eq(ImGroupUserDO::getDeleted, false)
        );
        
        if (groupUser == null) {
            throw exception(GROUP_PERMISSION_DENIED);
        }
    }

    /**
     * 转换为响应 VO
     */
    private AppImGroupFileRespVO convertToRespVO(ImGroupFileDO groupFile) {
        AppImGroupFileRespVO vo = BeanUtils.toBean(groupFile, AppImGroupFileRespVO.class);
        
        // 通过 FileApi 查询文件信息
        FileDTO fileDTO = fileApi.getFile(groupFile.getFileId());
        if (fileDTO != null) {
            vo.setFileName(fileDTO.getName());
            vo.setFileUrl(fileDTO.getUrl());
            vo.setFileType(fileDTO.getType());
            vo.setFileSize(fileDTO.getSize());
        } else {
            // 文件不存在时的默认值
            vo.setFileName("文件已删除");
            vo.setFileUrl("");
            vo.setFileType("");
            vo.setFileSize(0);
        }
        
        // 上传者名称
        AdminUserDO user = userMapper.selectById(groupFile.getUploaderId());
        if (user != null) {
            vo.setUploaderName(user.getNickname());
        }
        
        return vo;
    }

}
