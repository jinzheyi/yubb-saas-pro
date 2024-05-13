package com.shengyu.framework.common.util.validation;

import javax.validation.GroupSequence;

/**
 * @author zhusy
 * @description: 分组校验 - 定义分组
 * @date 2024/3/28 22:47
 */
public class ValidGroup {

    /**
     * 新增使用(配合spring的@Validated功能分组使用)
     */
    public interface Insert{}

    /**
     * 更新使用(配合spring的@Validated功能分组使用)
     */
    public interface Update{}

    /**
     * 删除使用(配合spring的@Validated功能分组使用)
     */
    public interface Delete{}

    /**
     * 属性必须有这两个分组的才验证(配合spring的@Validated功能分组使用)
     */
    @GroupSequence({Insert.class, Update.class})
    public interface saveOrUpdate{}

}
