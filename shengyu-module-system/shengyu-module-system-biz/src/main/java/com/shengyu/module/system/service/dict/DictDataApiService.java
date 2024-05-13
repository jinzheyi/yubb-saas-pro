package com.shengyu.module.system.service.dict;

import com.shengyu.module.platform.api.dict.dto.DictDataRespDTO;
import com.shengyu.module.platform.api.dict.dto.DictDataSimpleRespDTO;

import java.util.List;

/**
 * 字典数据 Service 接口
 *
 * @author ruoyi
 */
public interface DictDataApiService {

    /**
     * 获得字典数据列表
     *
     * @return 字典数据全列表
     */
    List<DictDataSimpleRespDTO> getDictDataList();

    /**
     * 获得字典数据列表
     *
     * @param dictType 字典类型
     * @return 字典数据列表
     */
    List<DictDataRespDTO> getEnabledDictDataListByType(String dictType);

}
