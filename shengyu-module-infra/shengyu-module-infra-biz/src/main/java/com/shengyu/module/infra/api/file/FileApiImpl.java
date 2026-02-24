package com.shengyu.module.infra.api.file;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.infra.api.file.dto.FileDTO;
import com.shengyu.module.infra.dal.dataobject.file.FileDO;
import com.shengyu.module.infra.dal.mysql.file.FileMapper;
import com.shengyu.module.infra.service.file.FileService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 文件 API 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class FileApiImpl implements FileApi {

    @Resource
    private FileService fileService;

    @Resource
    private FileMapper fileMapper;

    @Override
    public String createFile(byte[] content, String name, String directory, String type) {
        return fileService.createFile(content, name, directory, type);
    }

    @Override
    public Long createFileAndReturnId(byte[] content, String name, String directory, String type) {
        // 1. 创建文件，获取URL
        String url = fileService.createFile(content, name, directory, type);
        
        // 2. 通过URL查询文件ID
        FileDO file = getFileByUrlInternal(url);
        
        return file != null ? file.getId() : null;
    }

    @Override
    public FileDTO getFile(Long id) {
        FileDO file = fileService.getFile(id);
        return BeanUtils.toBean(file, FileDTO.class);
    }

    @Override
    public FileDTO getFileByUrl(String url) {
        FileDO file = getFileByUrlInternal(url);
        return BeanUtils.toBean(file, FileDTO.class);
    }

    @Override
    public void deleteFile(Long id) {
        try {
            fileService.deleteFile(id);
        } catch (Exception e) {
            throw new RuntimeException("删除文件失败", e);
        }
    }

    @Override
    public String presignGetUrl(String url, Integer expirationSeconds) {
        return fileService.presignGetUrl(url, expirationSeconds);
    }

    /**
     * 通过URL查询文件（内部方法）
     */
    private FileDO getFileByUrlInternal(String url) {
        LambdaQueryWrapper<FileDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FileDO::getUrl, url);
        wrapper.orderByDesc(FileDO::getId);
        wrapper.last("LIMIT 1");
        return fileMapper.selectOne(wrapper);
    }

}
