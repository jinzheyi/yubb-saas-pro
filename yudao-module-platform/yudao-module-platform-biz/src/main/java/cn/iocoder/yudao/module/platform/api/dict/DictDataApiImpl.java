package cn.iocoder.yudao.module.platform.api.dict;

import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataRespDTO;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;
import cn.iocoder.yudao.module.platform.convert.dict.DictDataConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.dict.DictDataDO;
import cn.iocoder.yudao.module.platform.service.dict.PlatformDictDataService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.List;

/**
 * 字典数据 API 实现类
 *
 * @author 芋道源码
 */
@Service
public class DictDataApiImpl implements DictDataApi {

    @Resource
    private PlatformDictDataService platformDictDataService;

    @Override
    public void validDictDatas(String dictType, Collection<String> values) {
        platformDictDataService.validDictDatas(dictType, values);
    }

    @Override
    public DictDataRespDTO getDictData(String dictType, String value) {
        DictDataDO dictData = platformDictDataService.getDictData(dictType, value);
        return DictDataConvert.INSTANCE.convert02(dictData);
    }

    @Override
    public DictDataRespDTO parseDictData(String dictType, String label) {
        DictDataDO dictData = platformDictDataService.parseDictData(dictType, label);
        return DictDataConvert.INSTANCE.convert02(dictData);
    }

    @Override
    public List<DictDataSimpleRespDTO> getDictDatas() {
        List<DictDataDO> dictDataDOS = platformDictDataService.getDictDatas();
        return DictDataConvert.INSTANCE.convertDTOList(dictDataDOS);
    }

}
