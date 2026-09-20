package com.shengyu.module.system.controller.admin.dashboard;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.framework.security.core.service.SecurityFrameworkService;
import com.shengyu.module.system.dal.dataobject.notice.NoticeDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.notice.NoticeMapper;
import com.shengyu.module.system.dal.mysql.notify.NotifyMessageMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import javax.annotation.Resource;
import lombok.Data;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 租户工作台")
@RestController
@RequestMapping("/system/dashboard")
public class TenantDashboardController {
    @Resource private AdminUserMapper userMapper;
    @Resource private NotifyMessageMapper notifyMessageMapper;
    @Resource private NoticeMapper noticeMapper;
    @Resource(name = "ss") private SecurityFrameworkService securityFrameworkService;

    @GetMapping("/tenant-overview")
    @Operation(summary = "获得当前租户工作台概览")
    public CommonResult<TenantOverviewRespVO> getTenantOverview() {
        TenantOverviewRespVO resp = new TenantOverviewRespVO();
        resp.setUnreadMessageCount(notifyMessageMapper.selectUnreadCountByUserIdAndUserType(
                getLoginUserId(), UserTypeEnum.ADMIN.getValue()));
        if (securityFrameworkService.hasPermission("system:user:query")) {
            resp.setUserCount(userMapper.selectCount());
            resp.setEnabledUserCount(userMapper.selectCount(new LambdaQueryWrapperX<AdminUserDO>()
                    .eq(AdminUserDO::getStatus, CommonStatusEnum.ENABLE.getStatus())));
        }
        if (securityFrameworkService.hasPermission("system:notice:query")) {
            resp.setRecentNotices(noticeMapper.selectList(new LambdaQueryWrapperX<NoticeDO>()
                    .eq(NoticeDO::getStatus, CommonStatusEnum.ENABLE.getStatus())
                    .orderByDesc(NoticeDO::getCreateTime).last("LIMIT 5")));
        }
        return success(resp);
    }

    @Data
    public static class TenantOverviewRespVO {
        private Long userCount;
        private Long enabledUserCount;
        private Long unreadMessageCount;
        private List<NoticeDO> recentNotices;
    }
}
