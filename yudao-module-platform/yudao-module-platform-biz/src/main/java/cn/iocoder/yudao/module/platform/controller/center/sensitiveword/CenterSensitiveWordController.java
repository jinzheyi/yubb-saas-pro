package cn.iocoder.yudao.module.platform.controller.center.sensitiveword;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.*;
import cn.iocoder.yudao.module.platform.convert.sensitiveword.SensitiveWordConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.sensitiveword.PlatformSensitiveWordDO;
import cn.iocoder.yudao.module.platform.service.sensitiveword.PlatformSensitiveWordService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;
import java.util.Set;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Api(tags = "管理后台 - 敏感词")
@RestController
@RequestMapping("/center/sensitive-word")
@Validated
public class CenterSensitiveWordController {

    @Resource
    private PlatformSensitiveWordService platformSensitiveWordService;

    @PostMapping("/create")
    @ApiOperation("创建敏感词")
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:create')")
    public CommonResult<Long> createSensitiveWord(@Valid @RequestBody SensitiveWordCreateReqVO createReqVO) {
        return success(platformSensitiveWordService.createSensitiveWord(createReqVO));
    }

    @PutMapping("/update")
    @ApiOperation("更新敏感词")
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:update')")
    public CommonResult<Boolean> updateSensitiveWord(@Valid @RequestBody SensitiveWordUpdateReqVO updateReqVO) {
        platformSensitiveWordService.updateSensitiveWord(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除敏感词")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:delete')")
    public CommonResult<Boolean> deleteSensitiveWord(@RequestParam("id") Long id) {
        platformSensitiveWordService.deleteSensitiveWord(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得敏感词")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:query')")
    public CommonResult<SensitiveWordRespVO> getSensitiveWord(@RequestParam("id") Long id) {
        PlatformSensitiveWordDO sensitiveWord = platformSensitiveWordService.getSensitiveWord(id);
        return success(SensitiveWordConvert.INSTANCE.convert(sensitiveWord));
    }

    @GetMapping("/page")
    @ApiOperation("获得敏感词分页")
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:query')")
    public CommonResult<PageResult<SensitiveWordRespVO>> getSensitiveWordPage(@Valid SensitiveWordPageReqVO pageVO) {
        PageResult<PlatformSensitiveWordDO> pageResult = platformSensitiveWordService.getSensitiveWordPage(pageVO);
        return success(SensitiveWordConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出敏感词 Excel")
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:export')")
    @OperateLog(type = EXPORT)
    public void exportSensitiveWordExcel(@Valid SensitiveWordExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<PlatformSensitiveWordDO> list = platformSensitiveWordService.getSensitiveWordList(exportReqVO);
        // 导出 Excel
        List<SensitiveWordExcelVO> datas = SensitiveWordConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "敏感词.xls", "数据", SensitiveWordExcelVO.class, datas);
    }

    @GetMapping("/get-tags")
    @ApiOperation("获取所有敏感词的标签数组")
    @PreAuthorize("@cs.hasPermission('center:sensitive-word:query')")
    public CommonResult<Set<String>> getSensitiveWordTags() throws IOException {
        return success(platformSensitiveWordService.getSensitiveWordTags());
    }

    @GetMapping("/validate-text")
    @ApiOperation("获得文本所包含的不合法的敏感词数组")
    public CommonResult<List<String>> validateText(@RequestParam("text") String text,
                                                   @RequestParam(value = "tags", required = false) List<String> tags) {
        return success(platformSensitiveWordService.validateText(text, tags));
    }

}
