package com.shengyu.module.infra.api.file;

import com.shengyu.module.infra.api.file.dto.FileDTO;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;

/**
 * 文件 API 接口
 *
 * @author 圣钰科技
 */
public interface FileApi {

    /**
     * 保存文件，并返回文件的访问路径
     *
     * @param content 文件内容
     * @return 文件路径
     */
    default String createFile(byte[] content) {
        return createFile(content, null, null, null);
    }

    /**
     * 保存文件，并返回文件的访问路径
     *
     * @param content 文件内容
     * @param name 文件名称，允许空
     * @return 文件路径
     */
    default String createFile(byte[] content, String name) {
        return createFile(content, name, null, null);
    }

    /**
     * 保存文件，并返回文件的访问路径
     *
     * @param content 文件内容
     * @param name 文件名称，允许空
     * @param directory 目录，允许空
     * @param type 文件的 MIME 类型，允许空
     * @return 文件路径
     */
    String createFile(@NotEmpty(message = "文件内容不能为空") byte[] content,
                      String name, String directory, String type);

    /**
     * 保存文件，并返回文件ID
     *
     * @param content 文件内容
     * @param name 文件名称
     * @param directory 目录
     * @param type 文件的 MIME 类型
     * @return 文件ID
     */
    Long createFileAndReturnId(@NotEmpty(message = "文件内容不能为空") byte[] content,
                               String name, String directory, String type);

    /**
     * 根据ID获取文件信息
     *
     * @param id 文件ID
     * @return 文件信息
     */
    FileDTO getFile(@NotNull(message = "文件ID不能为空") Long id);

    /**
     * 根据URL获取文件信息
     *
     * @param url 文件URL
     * @return 文件信息
     */
    FileDTO getFileByUrl(@NotEmpty(message = "文件URL不能为空") String url);

    /**
     * 删除文件
     *
     * @param id 文件ID
     */
    void deleteFile(@NotNull(message = "文件ID不能为空") Long id);

    /**
     * 生成文件预签名地址，用于读取
     *
     * @param url 完整的文件访问地址
     * @param expirationSeconds 访问有效期，单位秒
     * @return 文件预签名地址
     */
    String presignGetUrl(@NotEmpty(message = "URL 不能为空") String url,
                         Integer expirationSeconds);

}
