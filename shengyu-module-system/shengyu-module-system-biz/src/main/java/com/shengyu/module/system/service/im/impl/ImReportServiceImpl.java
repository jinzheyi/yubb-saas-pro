package com.shengyu.module.system.service.im.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.report.ImReportSaveReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImReportDO;
import com.shengyu.module.system.dal.mysql.im.ImReportMapper;
import com.shengyu.module.system.service.im.ImReportService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * 举报服务实现类
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Service
public class ImReportServiceImpl implements ImReportService {

    @Resource
    private ImReportMapper imReportMapper;

    @Resource
    private AdminUserService adminUserService;

    @Override
    public ImReportDO saveReport(ImReportSaveReqVO reqVO) {
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();

        // 不能举报自己
        if ("user".equals(reqVO.getReported_type()) && reqVO.getReported_id().equals(currentUserId)) {
            throw new ServiceException("不能举报自己");
        }

        // 被举报人是否存在
        if (adminUserService.getUser(reqVO.getReported_id()) == null) {
            throw new ServiceException("被举报人不存在");
        }

        // 检查之前是否举报过（还未处理）
        ImReportDO existingReport = imReportMapper.selectOne(
                new LambdaQueryWrapper<ImReportDO>()
                        .eq(ImReportDO::getReportedId, reqVO.getReported_id())
                        .eq(ImReportDO::getReportedType, reqVO.getReported_type())
                        .eq(ImReportDO::getStatus, "pending")
        );

        if (existingReport != null) {
            throw new ServiceException("请勿反复提交");
        }

        // 创建举报内容
        ImReportDO report = new ImReportDO();
        BeanUtils.copyProperties(reqVO, report);
        report.setUserId(currentUserId);
        imReportMapper.insert(report);

        return report;
    }
}