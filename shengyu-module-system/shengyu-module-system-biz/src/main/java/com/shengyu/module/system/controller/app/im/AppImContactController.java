package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactListByDeptReqVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactRespVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactSettingUpdateReqVO;
import com.shengyu.module.system.service.im.ImContactService;
import com.shengyu.module.system.service.im.ImSearchRateLimitService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.TOO_MANY_REQUESTS;

/**
 * 移动端 - IM 联系人 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 联系人")
@RestController
@RequestMapping("/system/im/contact")
@Validated
@DataPermission(enable = false)
public class AppImContactController {

    @Resource
    private ImContactService contactService;

    @Resource
    private ImSearchRateLimitService searchRateLimitService;

    @GetMapping("/list")
    @Operation(summary = "获取联系人列表（默认最多返回500条）")
    @Parameter(name = "limit", description = "返回上限（可选，默认500，最大1000）", required = false)
    public CommonResult<List<AppImContactRespVO>> getContactList(
            @RequestParam(value = "limit", required = false, defaultValue = "500") Integer limit) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        // 限制最大 limit
        if (limit > 1000) {
            limit = 1000;
        }
        return success(contactService.getContactList(userId, limit));
    }

    @GetMapping("/search")
    @Operation(summary = "搜索联系人")
    public ResponseEntity<CommonResult<PageResult<AppImContactRespVO>>> searchContact(@Valid AppImContactSearchReqVO searchReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = TenantContextHolder.getTenantId();
        ImSearchRateLimitService.CheckResult checkResult =
                searchRateLimitService.check(tenantId, userId, ImSearchRateLimitService.SCENE_CONTACT);
        if (!checkResult.isAllowed()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .header("Retry-After", String.valueOf(checkResult.getRetryAfterSeconds()))
                    .body(CommonResult.error(TOO_MANY_REQUESTS));
        }
        return ResponseEntity.ok(success(contactService.searchContactsPage(
                userId, searchReqVO.getKeyword(), searchReqVO.getPageNo(), searchReqVO.getPageSize())));
    }

    @GetMapping("/get")
    @Operation(summary = "获取联系人详情")
    @Parameter(name = "contactId", description = "联系人ID", required = true)
    public CommonResult<AppImContactRespVO> getContact(@RequestParam("contactId") Long contactId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(contactService.getContact(userId, contactId));
    }

    @PutMapping("/setting/update")
    @Operation(summary = "更新联系人设置")
    public CommonResult<Boolean> updateContactSetting(@Valid @RequestBody AppImContactSettingUpdateReqVO updateReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        contactService.updateContactSetting(userId, updateReqVO);
        return success(true);
    }

    @GetMapping("/list-by-dept")
    @Operation(summary = "根据部门ID获取联系人列表")
    @Parameter(name = "deptId", description = "部门ID", required = true)
    public CommonResult<List<AppImContactRespVO>> getContactListByDept(@RequestParam("deptId") Long deptId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(contactService.getContactListByDept(userId, deptId));
    }

    @GetMapping("/list-by-dept-page")
    @Operation(summary = "根据部门ID分页获取联系人列表")
    public CommonResult<PageResult<AppImContactRespVO>> getContactPageByDept(@Valid AppImContactListByDeptReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(contactService.getContactPageByDept(userId, reqVO));
    }

    @GetMapping("/list-star")
    @Operation(summary = "获取星标联系人列表（默认最多返回200条）")
    public CommonResult<List<AppImContactRespVO>> getStarContactList() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        // 星标联系人通常数量较少，限制最多200条
        return success(contactService.getStarContacts(userId, 200));
    }

}
