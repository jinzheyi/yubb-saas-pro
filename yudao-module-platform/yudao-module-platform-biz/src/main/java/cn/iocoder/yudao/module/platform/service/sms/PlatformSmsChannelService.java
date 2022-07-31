package cn.iocoder.yudao.module.platform.service.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsChannelDO;

import javax.validation.Valid;
import java.util.Collection;
import java.util.List;

/**
 * 短信渠道 Service 接口
 *
 * @author zzf
 * @date 2021/1/25 9:24
 */
public interface PlatformSmsChannelService {

    /**
     * 初始化短信客户端
     */
    void initSmsClients();

    /**
     * 创建短信渠道
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createSmsChannel(@Valid SmsChannelCreateReqVO createReqVO);

    /**
     * 更新短信渠道
     *
     * @param updateReqVO 更新信息
     */
    void updateSmsChannel(@Valid SmsChannelUpdateReqVO updateReqVO);

    /**
     * 删除短信渠道
     *
     * @param id 编号
     */
    void deleteSmsChannel(Long id);

    /**
     * 获得短信渠道
     *
     * @param id 编号
     * @return 短信渠道
     */
    PlatformSmsChannelDO getSmsChannel(Long id);

    /**
     * 获得短信渠道列表
     *
     * @param ids 编号
     * @return 短信渠道列表
     */
    List<PlatformSmsChannelDO> getSmsChannelList(Collection<Long> ids);

    /**
     * 获得所有短信渠道列表
     *
     * @return 短信渠道列表
     */
    List<PlatformSmsChannelDO> getSmsChannelList();

    /**
     * 获得短信渠道分页
     *
     * @param pageReqVO 分页查询
     * @return 短信渠道分页
     */
    PageResult<PlatformSmsChannelDO> getSmsChannelPage(SmsChannelPageReqVO pageReqVO);

}
