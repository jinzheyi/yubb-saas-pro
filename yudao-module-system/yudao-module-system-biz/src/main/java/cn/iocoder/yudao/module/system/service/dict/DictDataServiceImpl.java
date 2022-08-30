package cn.iocoder.yudao.module.system.service.dict;

import cn.iocoder.yudao.module.platform.api.dict.DictDataApi;
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
public class DictDataServiceImpl implements DictDataService {

    @Resource
    private DictDataApi dictDataApi;

    @Override
    public List<DictDataSimpleRespDTO> getDictDatas() {
        return dictDataApi.getDictDatas();
    }

}
