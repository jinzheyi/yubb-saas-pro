package com.shengyu.module.system.service.flow;


import com.shengyu.framework.mybatis.core.service.IBaseService;
import com.shengyu.module.system.controller.admin.flow.dto.TaskTransferConfigureDTO;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferConfigureVO;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwTransferConfigure;

/**
 * 流程转办配置 服务类
 *
 * @author 青苗
 * @since 2025-08-17
 */
public interface IFlwTransferConfigureService extends IBaseService<FlwTransferConfigure> {

    /**
     * 获取指定用户ID流程转办配置
     */
    TaskTransferConfigureVO getInfoByUserId(Long userId);

    /**
     * 保存指定用户ID流程转办配置
     */
    boolean saveInfo(TaskTransferConfigureDTO dto);

    /**
     * 我的流程转办配置
     */
    TaskTransferConfigureVO getMyConfigure();

    /**
     * 保存我的流程转办配置
     */
    boolean saveMyConfigure(TaskTransferConfigureDTO dto);

    /**
     * 获取用户指定转办处理人
     */
    TaskTransferVO getTaskTransfer(Long userId);
}
