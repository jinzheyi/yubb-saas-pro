package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.file.AppImGroupFilePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.file.AppImGroupFileRespVO;
import org.springframework.web.multipart.MultipartFile;

/**
 * IM 群文件 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImGroupFileService {

    /**
     * 上传群文件
     *
     * @param groupId 群组ID
     * @param file 文件
     * @return 文件信息
     */
    AppImGroupFileRespVO uploadFile(Long groupId, MultipartFile file) throws Exception;

    /**
     * 获取群文件列表（分页）
     *
     * @param pageReqVO 分页请求
     * @return 文件列表
     */
    PageResult<AppImGroupFileRespVO> getFileList(AppImGroupFilePageReqVO pageReqVO);

    /**
     * 删除群文件
     *
     * @param id 文件ID
     */
    void deleteFile(Long id);

    /**
     * 增加下载次数
     *
     * @param id 文件ID
     */
    void incrementDownloadCount(Long id);

}
