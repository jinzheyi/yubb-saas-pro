package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteAddReqVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoritePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteResendReqVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteRespVO;
import com.shengyu.module.system.service.im.ImFavoriteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - IM 消息收藏")
@RestController
@RequestMapping("/system/im/favorite")
@Validated
@DataPermission(enable = false)
public class AppImFavoriteController {

    @Resource
    private ImFavoriteService favoriteService;

    @PostMapping("/add")
    @Operation(summary = "收藏消息")
    public CommonResult<Boolean> addFavorite(@Valid @RequestBody AppImFavoriteAddReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        favoriteService.addFavorite(userId, reqVO.getMessageId());
        return success(true);
    }

    @DeleteMapping("/remove")
    @Operation(summary = "取消收藏消息")
    @Parameter(name = "favoriteId", description = "收藏ID", required = true)
    public CommonResult<Boolean> removeFavorite(@RequestParam("favoriteId") Long favoriteId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        favoriteService.removeFavorite(userId, favoriteId);
        return success(true);
    }

    @GetMapping("/list")
    @Operation(summary = "分页查询收藏列表")
    public CommonResult<PageResult<AppImFavoriteRespVO>> getFavoritePage(@Valid AppImFavoritePageReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(favoriteService.getFavoritePage(userId, reqVO));
    }

    @GetMapping("/detail")
    @Operation(summary = "查询收藏详情")
    @Parameter(name = "favoriteId", description = "收藏ID", required = true)
    public CommonResult<AppImFavoriteRespVO> getFavoriteDetail(@RequestParam("favoriteId") Long favoriteId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(favoriteService.getFavoriteDetail(userId, favoriteId));
    }

    @PostMapping("/resend")
    @Operation(summary = "收藏消息单条发送到会话")
    public CommonResult<String> resendFavorite(@Valid @RequestBody AppImFavoriteResendReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long messageId = favoriteService.resendFavorite(userId, reqVO.getFavoriteId(), reqVO.getTargetChatId());
        return success(messageId == null ? "0" : String.valueOf(messageId));
    }
}
