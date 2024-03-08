package cn.iocoder.yudao.module.system.controller.admin.dict;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.dict.vo.data.DictDataSimpleRespVO;
import cn.iocoder.yudao.module.system.service.dict.DictDataApiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 字典数据")
@RestController
@RequestMapping("/system/dict-data")
@Validated
public class TenantDictDataController {

    @Resource
    private DictDataApiService dictDataApiService;

    @GetMapping(value = {"/list-all-simple", "simple-list"})
    @Operation(summary = "获得全部字典数据列表", description = "一般用于管理后台缓存字典数据在本地")
    // 无需添加权限认证，因为前端全局都需要
    public CommonResult<List<DictDataSimpleRespVO>> getSimpleDictDataList() {
        List<DictDataSimpleRespDTO> list = dictDataApiService.getDictDataList();
        return success(BeanUtils.toBean(list, DictDataSimpleRespVO.class));
    }

}
