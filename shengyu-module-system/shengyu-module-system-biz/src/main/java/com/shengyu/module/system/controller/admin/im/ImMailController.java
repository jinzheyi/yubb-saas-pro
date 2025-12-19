package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailBlackReqVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailDeleteReqVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailMomentAuthReqVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailRemarkTagReqVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailStarReqVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailUserDetailRespVO;
import com.shengyu.module.system.service.im.ImMailService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/11/19 15:01
 */
@Tag(name = "通讯录相关业务接口")
@RestController
@RequestMapping("/im/mail")
@Validated
public class ImMailController {

    @Resource
    private ImMailService imMailService;

    @GetMapping("/list")
    @Operation(summary = "获取用户通讯录列表")
    public CommonResult<ImMailListRespVO> getMailList() {
        return success(imMailService.list());
    }

    @GetMapping("/read/{id}")
    @Operation(summary = "查看用户资料")
    public CommonResult<ImMailUserDetailRespVO> read(@PathVariable Long id) {
        return success(imMailService.getUserDetail(id));
    }

    @PutMapping("/setblack/{id}")
    @Operation(summary = "移入/移除黑名单")
    public CommonResult<Boolean> setBlack(@PathVariable Long id, @RequestBody ImMailBlackReqVO reqVO) {
        imMailService.updateBlackStatus(id, reqVO.getIsblack());
        return success(true);
    }

    @PutMapping("/setstar/{id}")
    @Operation(summary = "设置/取消星标好友")
    public CommonResult<Boolean> setStar(@PathVariable Long id, @RequestBody ImMailStarReqVO reqVO) {
        imMailService.updateStarStatus(id, reqVO.getStar());
        return success(true);
    }
    
    @PutMapping("/setmomentauth/{id}")
    @Operation(summary = "设置朋友圈权限")
    public CommonResult<Boolean> setMomentAuth(@PathVariable Long id, @RequestBody ImMailMomentAuthReqVO reqVO) {
        imMailService.setMomentAuth(id, reqVO.getLookme(), reqVO.getLookhim());
        return success(true);
    }
    
    @PutMapping("/setremarktag/{id}")
    @Operation(summary = "设置备注和标签")
    public CommonResult<Boolean> setRemarkTag(@PathVariable Long id, @RequestBody ImMailRemarkTagReqVO reqVO) {
        imMailService.setRemarkTag(id, reqVO.getNickname(), reqVO.getTags());
        return success(true);
    }
    
    @PostMapping("/destroy")
    @Operation(summary = "删除好友")
    public CommonResult<Boolean> destroy(@RequestBody ImMailDeleteReqVO reqVO) {
        imMailService.deleteFriend(reqVO.getFriend_id());
        return success(true);
    }

}
