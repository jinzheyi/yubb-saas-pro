package com.shengyu.module.platform.controller.platform.dept;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostCreateReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostExcelVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostExportReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostPageReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostRespVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostSimpleRespVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformPostDO;
import com.shengyu.module.platform.service.dept.PlatformPostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 岗位")
@RestController
@RequestMapping("/system/post")
@Validated
public class PlatformPostController {

    @Resource
    private PlatformPostService platformPostService;

    @PostMapping("/create")
    @Operation(summary = "创建岗位")
    @PreAuthorize("@ps.hasPermission('system:post:create')")
    public CommonResult<Long> createPost(@Valid @RequestBody PostCreateReqVO reqVO) {
        Long postId = platformPostService.createPost(reqVO);
        return success(postId);
    }

    @PutMapping("/update")
    @Operation(summary = "修改岗位")
    @PreAuthorize("@ps.hasPermission('system:post:update')")
    public CommonResult<Boolean> updatePost(@Valid @RequestBody PostUpdateReqVO reqVO) {
        platformPostService.updatePost(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除岗位")
    @PreAuthorize("@ps.hasPermission('system:post:delete')")
    public CommonResult<Boolean> deletePost(@RequestParam("id") Long id) {
        platformPostService.deletePost(id);
        return success(true);
    }

    @GetMapping(value = "/get")
    @Operation(summary = "获得岗位信息")
    @Parameter(name = "id", description = "岗位编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:post:query')")
    public CommonResult<PostRespVO> getPost(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(platformPostService.getPost(id), PostRespVO.class));
    }

    @GetMapping("/list-all-simple")
    @Operation(summary = "获取岗位精简信息列表", description = "只包含被开启的岗位，主要用于前端的下拉选项")
    public CommonResult<List<PostSimpleRespVO>> getSimplePostList() {
        // 获得岗位列表，只要开启状态的
        List<PlatformPostDO> list = platformPostService.getPostList(null, Collections.singleton(CommonStatusEnum.ENABLE.getStatus()));
        // 排序后，返回给前端
        list.sort(Comparator.comparing(PlatformPostDO::getSort));
        return success(BeanUtils.toBean(list, PostSimpleRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得岗位分页列表")
    @PreAuthorize("@ps.hasPermission('system:post:query')")
    public CommonResult<PageResult<PostRespVO>> getPostPage(@Validated PostPageReqVO reqVO) {
        return success(BeanUtils.toBean(platformPostService.getPostPage(reqVO), PostRespVO.class));
    }

    @GetMapping("/export")
    @Operation(summary = "岗位管理")
    @PreAuthorize("@ps.hasPermission('system:post:export')")
    @OperateLog(type = EXPORT)
    public void export(HttpServletResponse response, @Validated PostExportReqVO reqVO) throws IOException {
        List<PlatformPostDO> posts = platformPostService.getPostList(reqVO);
        List<PostExcelVO> data = BeanUtils.toBean(posts, PostExcelVO.class);
        // 输出
        ExcelUtils.write(response, "岗位数据.xls", "岗位列表", PostExcelVO.class, data);
    }

}
