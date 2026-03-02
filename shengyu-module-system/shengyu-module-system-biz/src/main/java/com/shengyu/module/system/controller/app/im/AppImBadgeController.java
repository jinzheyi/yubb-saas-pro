package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.websocket.core.protocol.BadgeUpdateMessage;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImBadgeRespVO;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImConversationBadgeRespVO;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImMenuBadgeRespVO;
import com.shengyu.module.system.service.im.ImBadgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 角标 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 角标")
@RestController
@RequestMapping("/system/im/badge")
@Validated
@DataPermission(enable = false)
public class AppImBadgeController {

    @Resource
    private ImBadgeService imBadgeService;

    @GetMapping("/get")
    @Operation(summary = "获取角标数据")
    public CommonResult<AppImBadgeRespVO> getBadgeData() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();

		BadgeUpdateMessage badgeUpdateMessage = imBadgeService.getBadgeData(userId);
		AppImBadgeRespVO respVO = new AppImBadgeRespVO();
		respVO.setUnreadCount(badgeUpdateMessage.getUnreadCount());
		respVO.setConversationBadges(badgeUpdateMessage.getConversationBadgesList().stream().map(item -> {
			AppImConversationBadgeRespVO badge = new AppImConversationBadgeRespVO();
			badge.setChatId(item.getConversationId());
			badge.setUnreadCount(item.getUnreadCount());
			return badge;
		}).collect(java.util.stream.Collectors.toList()));
		respVO.setMenuBadges(badgeUpdateMessage.getMenuBadgesList().stream().map(item -> {
			AppImMenuBadgeRespVO badge = new AppImMenuBadgeRespVO();
			badge.setMenuId(item.getMenuId());
			badge.setBadgeCount(item.getBadgeCount());
			return badge;
		}).collect(java.util.stream.Collectors.toList()));
		return success(respVO);
    }

}
