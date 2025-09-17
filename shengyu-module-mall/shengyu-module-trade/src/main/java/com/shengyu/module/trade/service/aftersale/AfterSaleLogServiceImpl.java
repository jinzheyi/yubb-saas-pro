package com.shengyu.module.trade.service.aftersale;

import com.shengyu.module.trade.convert.aftersale.AfterSaleLogConvert;
import com.shengyu.module.trade.dal.dataobject.aftersale.AfterSaleLogDO;
import com.shengyu.module.trade.dal.mysql.aftersale.AfterSaleLogMapper;
import com.shengyu.module.trade.service.aftersale.bo.AfterSaleLogCreateReqBO;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

/**
 * 交易售后日志 Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class AfterSaleLogServiceImpl implements AfterSaleLogService {

    @Resource
    private AfterSaleLogMapper afterSaleLogMapper;

    @Override
    public void createAfterSaleLog(AfterSaleLogCreateReqBO createReqBO) {
        AfterSaleLogDO afterSaleLog = AfterSaleLogConvert.INSTANCE.convert(createReqBO);
        afterSaleLogMapper.insert(afterSaleLog);
    }

    @Override
    public List<AfterSaleLogDO> getAfterSaleLogList(Long afterSaleId) {
        return afterSaleLogMapper.selectListByAfterSaleId(afterSaleId);
    }

}
