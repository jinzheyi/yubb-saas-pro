package com.shengyu.module.system.service.im;

import cn.hutool.core.io.IoUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.infra.controller.platform.file.vo.file.FileCreateReqVO;
import com.shengyu.module.infra.dal.dataobject.file.FileDO;
import com.shengyu.module.infra.dal.mysql.file.FileMapper;
import com.shengyu.module.infra.service.file.FileService;
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
    private FileService fileService;

    @Resource
    private FileMapper fileMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupFileRespVO uploadFile(Long groupId, MultipartFile file) throws Exception {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 1. 验证权限：用户必须是群成员
        validateGroupMember(groupId, userId);
        
        // 2. 上传文件到文件服务，获取文件 URL
        String directory = "im/group/" + groupId;
        byte[] content = IoUtil.readBytes(file.getInputStream());
        String fileUrl = fileService.createFile(content, file.getOriginalFilename(), directory, file.getContentType());
        
        // 3. 通过 URL 查询文件 ID
        // 注意：这里需要从 URL 中提取路径，然后查询文件
        // URL 格式通常是：http://domain/path 或 /path
        FileDO fileDO = findFileByUrl(fileUrl);
        if (fileDO == null) {
            throw exception(GROUP_FILE_NOT_EXISTS);
        }
        
        // 4. 创建群文件关联记录
        ImGroupFileDO groupFile = ImGroupFileDO.builder()
                .groupId(groupId)
                .fileId(fileDO.getId())
                .uploaderId(userId)
                .folderId(0L)
                .isFavorite(false)
                .downloadCount(0)
                .build();
        
        groupFileMapper.insert(groupFile);
        
        log.info("[ImGroupFileService] 上传群文件成功, groupId: {}, userId: {}, fileId: {}, fileName: {}", 
                groupId, userId, fileDO.getId(), file.getOriginalFilename());
        
        // 5. 返回文件信息
        return buildFileRespVO(groupFile, fileDO);
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
     * 构建文件响应 VO
     */
    private AppImGroupFileRespVO buildFileRespVO(ImGroupFileDO groupFile, FileDO fileDO) {
        AppImGroupFileRespVO vo = new AppImGroupFileRespVO();
        vo.setId(groupFile.getId());
        vo.setGroupId(groupFile.getGroupId());
        vo.setFileId(groupFile.getFileId());
        vo.setUploaderId(groupFile.getUploaderId());
        vo.setDownloadCount(groupFile.getDownloadCount());
        vo.setCreateTime(groupFile.getCreateTime());
        
        // 文件信息
        vo.setFileName(fileDO.getName());
        vo.setFileUrl(fileDO.getUrl());
        vo.setFileType(fileDO.getType());
        vo.setFileSize(fileDO.getSize());
        
        // 上传者名称
        AdminUserDO user = userMapper.selectById(groupFile.getUploaderId());
        if (user != null) {
            vo.setUploaderName(user.getNickname());
        }
        
        return vo;
    }

    /**
     * 转换为响应 VO
     */
    private AppImGroupFileRespVO convertToRespVO(ImGroupFileDO groupFile) {
        AppImGroupFileRespVO vo = BeanUtils.toBean(groupFile, AppImGroupFileRespVO.class);
        
        // 查询文件信息
        FileDO fileDO = fileService.getFile(groupFile.getFileId());
        if (fileDO != null) {
            vo.setFileName(fileDO.getName());
            vo.setFileUrl(fileDO.getUrl());
            vo.setFileType(fileDO.getType());
            vo.setFileSize(fileDO.getSize());
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

    /**
     * 通过 URL 查找文件
     */
    private FileDO findFileByUrl(String url) {
        // 通过 URL 查询文件
        LambdaQueryWrapper<FileDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FileDO::getUrl, url);
        wrapper.orderByDesc(FileDO::getId);
        wrapper.last("LIMIT 1");
        return fileMapper.selectOne(wrapper);
    }

}
