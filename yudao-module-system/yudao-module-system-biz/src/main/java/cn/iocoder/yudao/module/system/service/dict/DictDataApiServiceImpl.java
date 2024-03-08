package cn.iocoder.yudao.module.system.service.dict;

import cn.iocoder.yudao.module.platform.api.dict.DictDataApi;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataRespDTO;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 字典数据 Service 实现类
 *
 * @author ruoyi
 */
@Service
@Slf4j
public class DictDataApiServiceImpl implements DictDataApiService {

    @Resource
    private DictDataApi dictDataApi;

    @Override
    public List<DictDataSimpleRespDTO> getDictDataList() {
        return dictDataApi.getDictDataList();
    }

    @Override
    public List<DictDataRespDTO> getEnabledDictDataListByType(String dictType) {
        return dictDataApi.getEnabledDictDataListByType(dictType);
    }

}
