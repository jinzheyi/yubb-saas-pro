package cn.iocoder.yudao.module.platform.convert.dept;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface PostConvert {

    PostConvert INSTANCE = Mappers.getMapper(PostConvert.class);

    List<PostSimpleRespVO> convertList02(List<PlatformPostDO> list);

    PageResult<PostRespVO> convertPage(PageResult<PlatformPostDO> page);

    PostRespVO convert(PlatformPostDO id);

    PlatformPostDO convert(PostCreateReqVO bean);

    PlatformPostDO convert(PostUpdateReqVO reqVO);

    List<PostExcelVO> convertList03(List<PlatformPostDO> list);

}
