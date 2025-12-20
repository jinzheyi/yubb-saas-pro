package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.fava.ImFavaCreateReqVO;
import com.shengyu.module.system.controller.admin.im.vo.fava.ImFavaDeleteReqVO;
import com.shengyu.module.system.controller.admin.im.vo.report.ImReportSaveReqVO;
import com.shengyu.module.system.controller.admin.im.vo.tag.ImTagListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.tag.ImTagUserListRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImFavaDO;
import com.shengyu.module.system.dal.dataobject.im.ImReportDO;
import com.shengyu.module.system.service.im.ImFavaService;
import com.shengyu.module.system.service.im.ImReportService;
import com.shengyu.module.system.service.im.ImTagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

/**
 * 我的相关业务接口
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/11/19 15:01
 */
@Tag(name = "我的相关业务接口")
@RestController
@RequestMapping("/im/my")
@Validated
public class ImMyController {

    @Resource
    private ImFavaService imFavaService;

    @Resource
    private ImReportService imReportService;

    @Resource
    private ImTagService imTagService;

    /**
     * 创建收藏
     *
     * @param reqVO 创建收藏请求
     * @return 成功响应
     */
    @PostMapping("/fava/create")
    @Operation(summary = "创建收藏")
    public CommonResult<ImFavaDO> createFava(@RequestBody @Validated ImFavaCreateReqVO reqVO) {
        ImFavaDO fava = imFavaService.createFava(reqVO);
        return CommonResult.success(fava);
    }

    /**
     * 获取收藏列表
     *
     * @param page 页码，默认1
     * @param limit 每页数量，默认10
     * @return 收藏列表
     */
    @GetMapping("/fava/list")
    @Operation(summary = "获取收藏列表")
    public CommonResult<List<ImFavaDO>> getFavaList(
            @Parameter(description = "页码，默认1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页数量，默认10") @RequestParam(defaultValue = "10") int limit) {
        List<ImFavaDO> favaList = imFavaService.getFavaList(page, limit);
        return CommonResult.success(favaList);
    }

    /**
     * 删除收藏
     *
     * @param reqVO 删除收藏请求
     * @return 成功响应
     */
    @PostMapping("/fava/delete")
    @Operation(summary = "删除收藏")
    public CommonResult<Boolean> deleteFava(@RequestBody @Validated ImFavaDeleteReqVO reqVO) {
        boolean result = imFavaService.deleteFava(reqVO);
        return CommonResult.success(result);
    }

    // ---------------------------- 举报相关接口 ----------------------------

    /**
     * 保存举报
     *
     * @param reqVO 举报请求
     * @return 举报信息
     */
    @PostMapping("/report/save")
    @Operation(summary = "保存举报")
    public CommonResult<ImReportDO> saveReport(@RequestBody @Validated ImReportSaveReqVO reqVO) {
        ImReportDO report = imReportService.saveReport(reqVO);
        return CommonResult.success(report);
    }

    // ---------------------------- 标签相关接口 ----------------------------

    /**
     * 获取标签列表
     *
     * @return 标签列表
     */
    @GetMapping("/tag/list")
    @Operation(summary = "获取标签列表")
    public CommonResult<List<ImTagListRespVO>> getTagList() {
        List<ImTagListRespVO> tagList = imTagService.getTagList();
        return CommonResult.success(tagList);
    }

    /**
     * 获取标签用户列表
     *
     * @param id 标签ID
     * @return 标签用户列表
     */
    @GetMapping("/tag/read/{id}")
    @Operation(summary = "获取标签用户列表")
    public CommonResult<List<ImTagUserListRespVO>> getTagUserList(
            @Parameter(description = "标签ID") @PathVariable Long id) {
        List<ImTagUserListRespVO> userList = imTagService.getTagUserList(id);
        return CommonResult.success(userList);
    }
}
