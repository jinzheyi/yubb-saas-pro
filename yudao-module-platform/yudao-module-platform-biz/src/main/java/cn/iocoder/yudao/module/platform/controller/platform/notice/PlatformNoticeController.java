package cn.iocoder.yudao.module.platform.controller.platform.notice;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticeCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticePageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticeRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticeUpdateReqVO;
import cn.iocoder.yudao.module.platform.service.notice.PlatformNoticeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
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

@Tag(name = "管理后台 - 通知公告")
@RestController
@RequestMapping("/system/notice")
@Validated
public class PlatformNoticeController {

    @Resource
    private PlatformNoticeService platformNoticeService;

    @PostMapping("/create")
    @Operation(summary = "创建通知公告")
    @PreAuthorize("@ps.hasPermission('system:notice:create')")
    public CommonResult<Long> createNotice(@Valid @RequestBody NoticeCreateReqVO reqVO) {
        Long noticeId = platformNoticeService.createNotice(reqVO);
        return success(noticeId);
    }

    @PutMapping("/update")
    @Operation(summary = "修改通知公告")
    @PreAuthorize("@ps.hasPermission('system:notice:update')")
    public CommonResult<Boolean> updateNotice(@Valid @RequestBody NoticeUpdateReqVO reqVO) {
        platformNoticeService.updateNotice(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除通知公告")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:notice:delete')")
    public CommonResult<Boolean> deleteNotice(@RequestParam("id") Long id) {
        platformNoticeService.deleteNotice(id);
        return success(true);
    }

    @GetMapping("/page")
    @Operation(summary = "获取通知公告列表")
    @PreAuthorize("@ps.hasPermission('system:notice:query')")
    public CommonResult<PageResult<NoticeRespVO>> getNoticePage(@Validated NoticePageReqVO reqVO) {
        return success(BeanUtils.toBean(platformNoticeService.getNoticePage(reqVO), NoticeRespVO.class));
    }

    @GetMapping("/get")
    @Operation(summary = "获得通知公告")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:notice:query')")
    public CommonResult<NoticeRespVO> getNotice(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(platformNoticeService.getNotice(id), NoticeRespVO.class));
    }

}
