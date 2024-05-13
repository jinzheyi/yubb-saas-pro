package com.shengyu.module.platform.controller.platform.mail;


import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.mail.vo.account.MailAccountPageReqVO;
import com.shengyu.module.platform.controller.platform.mail.vo.account.MailAccountRespVO;
import com.shengyu.module.platform.controller.platform.mail.vo.account.MailAccountSaveReqVO;
import com.shengyu.module.platform.controller.platform.mail.vo.account.MailAccountSimpleRespVO;
import com.shengyu.module.platform.dal.dataobject.mail.MailAccountDO;
import com.shengyu.module.platform.service.mail.MailAccountService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 邮箱账号")
@RestController
@RequestMapping("/system/mail-account")
public class MailAccountController {

    @Resource
    private MailAccountService mailAccountService;

    @PostMapping("/create")
    @Operation(summary = "创建邮箱账号")
    @PreAuthorize("@ps.hasPermission('system:mail-account:create')")
    public CommonResult<Long> createMailAccount(@Valid @RequestBody MailAccountSaveReqVO createReqVO) {
        return success(mailAccountService.createMailAccount(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "修改邮箱账号")
    @PreAuthorize("@ps.hasPermission('system:mail-account:update')")
    public CommonResult<Boolean> updateMailAccount(@Valid @RequestBody MailAccountSaveReqVO updateReqVO) {
        mailAccountService.updateMailAccount(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除邮箱账号")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ps.hasPermission('system:mail-account:delete')")
    public CommonResult<Boolean> deleteMailAccount(@RequestParam Long id) {
        mailAccountService.deleteMailAccount(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得邮箱账号")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:mail-account:get')")
    public CommonResult<MailAccountRespVO> getMailAccount(@RequestParam("id") Long id) {
        MailAccountDO account = mailAccountService.getMailAccount(id);
        return success(BeanUtils.toBean(account, MailAccountRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得邮箱账号分页")
    @PreAuthorize("@ps.hasPermission('system:mail-account:query')")
    public CommonResult<PageResult<MailAccountRespVO>> getMailAccountPage(@Valid MailAccountPageReqVO pageReqVO) {
        PageResult<MailAccountDO> pageResult = mailAccountService.getMailAccountPage(pageReqVO);
        return success(BeanUtils.toBean(pageResult, MailAccountRespVO.class));
    }

    @GetMapping({"/list-all-simple", "simple-list"})
    @Operation(summary = "获得邮箱账号精简列表")
    public CommonResult<List<MailAccountSimpleRespVO>> getSimpleMailAccountList() {
        List<MailAccountDO> list = mailAccountService.getMailAccountList();
        return success(BeanUtils.toBean(list, MailAccountSimpleRespVO.class));
    }

}
