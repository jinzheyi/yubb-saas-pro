package com.shengyu.module.system.service.flow.impl;

import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.flowlong.engine.assist.DateUtils;
import com.shengyu.framework.mybatis.core.service.BaseServiceImpl;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.flow.dto.TaskTransferConfigureDTO;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferConfigureVO;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwTransferConfigure;
import com.shengyu.module.system.dal.mysql.flow.FlwTransferConfigureMapper;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.service.flow.IFlwTransferConfigureService;
import com.shengyu.module.system.service.user.AdminUserService;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 流程转办配置 服务实现类
 *
 * @author 青苗
 * @since 2025-08-17
 */
@Service
@AllArgsConstructor
public class FlwTransferConfigureServiceImpl extends
  BaseServiceImpl<FlwTransferConfigureMapper, FlwTransferConfigure> implements
  IFlwTransferConfigureService {
    private AdminUserService sysUserService;

    @Override
    public TaskTransferConfigureVO getInfoByUserId(Long userId) {
        FlwTransferConfigure ftc = this.getByUserId(userId);
        if (null != ftc) {
            TaskTransferConfigureVO vo = ftc.convert(TaskTransferConfigureVO.class);
            UserRespVO sysUser = sysUserService.getUser(vo.getTransferId());
            if (null != sysUser) {
                vo.setTransferName(sysUser.getNickname());
            }
            return vo;
        }
        return null;
    }

    @Override
    public boolean saveInfo(TaskTransferConfigureDTO dto) {
        Long userId = dto.getUserId();
        ServiceExceptionUtil.isEmpty(userId, ErrorCodeConstants.FLOW_1_002_029_057);
        ServiceExceptionUtil.fail(Objects.equals(userId, dto.getTransferId()), ErrorCodeConstants.FLOW_1_002_029_058);
        boolean paramsIsNull = null == dto.getBeginTime() || null == dto.getEndTime()
                || null == dto.getTransferId();
        FlwTransferConfigure ftc = dto.convert(FlwTransferConfigure.class);
        FlwTransferConfigure dbFtc = this.getByUserId(userId);
        if (null != dbFtc) {
            if (paramsIsNull) {
                // 删除
                return super.removeById(dbFtc.getId());
            }

            // 更新
            ftc.setId(dbFtc.getId());
            ftc.setUserId(userId);
            return super.updateById(ftc);
        }

        // 保存
        ServiceExceptionUtil.fail(paramsIsNull, ErrorCodeConstants.FLOW_1_002_029_059);
        ftc.setUserId(userId);
        return super.save(ftc);
    }

    @Override
    public TaskTransferConfigureVO getMyConfigure() {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        return this.getInfoByUserId(userSession.getId());
    }

    @Override
    public boolean saveMyConfigure(TaskTransferConfigureDTO dto) {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        // 默认设置当前用户
        dto.setUserId(userSession.getId());
        return this.saveInfo(dto);
    }

    private FlwTransferConfigure getByUserId(Long userId) {
        List<FlwTransferConfigure> ftcList = super.list(Wrappers.<FlwTransferConfigure>lambdaQuery()
                .eq(FlwTransferConfigure::getUserId, userId));
        return CollUtil.isEmpty(ftcList) ? null : ftcList.get(0);
    }

    @Override
    public TaskTransferVO getTaskTransfer(Long userId) {
        return baseMapper.selectByUserId(userId, DateUtils.toDate(LocalDateTime.now()));
    }
}
