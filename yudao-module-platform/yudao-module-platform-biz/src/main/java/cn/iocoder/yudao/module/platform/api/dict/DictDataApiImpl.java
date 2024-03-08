package cn.iocoder.yudao.module.platform.api.dict;

import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataRespDTO;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dict.DictDataDO;
import cn.iocoder.yudao.module.platform.service.dict.DictDataService;
import java.util.Collection;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 字典数据 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class DictDataApiImpl implements DictDataApi {

    @Resource
    private DictDataService dictDataService;

    @Override
    public void validateDictDataList(String dictType, Collection<String> values) {
        dictDataService.validateDictDataList(dictType, values);
    }

    @Override
    public DictDataRespDTO getDictData(String dictType, String value) {
        DictDataDO dictData = dictDataService.getDictData(dictType, value);
        return BeanUtils.toBean(dictData, DictDataRespDTO.class);
    }

    @Override
    public DictDataRespDTO parseDictData(String dictType, String label) {
        DictDataDO dictData = dictDataService.parseDictData(dictType, label);
        return BeanUtils.toBean(dictData, DictDataRespDTO.class);
    }

    @Override
    public List<DictDataSimpleRespDTO> getDictDataList() {
        List<DictDataDO> dictDataDOS = dictDataService.getDictDataList();
        return BeanUtils.toBean(dictDataDOS, DictDataSimpleRespDTO.class);
    }

    @Override
    public List<DictDataRespDTO> getEnabledDictDataListByType(String dictType) {
        List<DictDataDO> dictDataDOList = dictDataService.getEnabledDictDataListByType(dictType);
        return BeanUtils.toBean(dictDataDOList, DictDataRespDTO.class);
    }

}
