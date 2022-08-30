package cn.iocoder.yudao.module.system.controller.admin.dict;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.dict.vo.data.DictDataSimpleRespVO;
import cn.iocoder.yudao.module.system.convert.dict.DictDataConvert;
import cn.iocoder.yudao.module.system.service.dict.DictDataService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "管理后台 - 字典数据")
@RestController
@RequestMapping("/system/dict-data")
@Validated
public class DictDataController {

    @Resource
    private DictDataService dictDataService;

    @GetMapping("/list-all-simple")
    @ApiOperation(value = "获得全部字典数据列表", notes = "一般用于管理后台缓存字典数据在本地")
    // 无需添加权限认证，因为前端全局都需要
    public CommonResult<List<DictDataSimpleRespVO>> getSimpleDictDatas() {
        List<DictDataSimpleRespDTO> list = dictDataService.getDictDatas();
        return success(DictDataConvert.INSTANCE.convertList(list));
    }

}
