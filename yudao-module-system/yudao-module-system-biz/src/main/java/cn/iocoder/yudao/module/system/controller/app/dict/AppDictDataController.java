package cn.iocoder.yudao.module.system.controller.app.dict;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataRespDTO;
import cn.iocoder.yudao.module.system.controller.app.dict.vo.AppDictDataRespVO;
import cn.iocoder.yudao.module.system.service.dict.DictDataApiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "用户 App - 字典数据")
@RestController
@RequestMapping("/system/dict-data")
@Validated
public class AppDictDataController {

    @Resource
    private DictDataApiService dictDataApiService;

    @GetMapping("/type")
    @Operation(summary = "根据字典类型查询字典数据信息")
    @Parameter(name = "type", description = "字典类型", required = true, example = "common_status")
    public CommonResult<List<AppDictDataRespVO>> getDictDataListByType(
        @RequestParam("type") String type) {
        List<DictDataRespDTO> list = dictDataApiService.getEnabledDictDataListByType(type);
        return success(BeanUtils.toBean(list, AppDictDataRespVO.class));
    }

}
