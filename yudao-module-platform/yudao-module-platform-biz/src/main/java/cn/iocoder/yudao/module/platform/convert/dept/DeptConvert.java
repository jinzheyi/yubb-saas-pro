package cn.iocoder.yudao.module.platform.convert.dept;

import cn.iocoder.yudao.module.platform.api.dept.dto.DeptRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptRespVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.DeptDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface DeptConvert {

    DeptConvert INSTANCE = Mappers.getMapper(DeptConvert.class);

    List<DeptRespVO> convertList(List<DeptDO> list);

    List<DeptSimpleRespVO> convertList02(List<DeptDO> list);

    DeptRespVO convert(DeptDO bean);

    DeptDO convert(DeptCreateReqVO bean);

    DeptDO convert(DeptUpdateReqVO bean);

    List<DeptRespDTO> convertList03(List<DeptDO> list);

    DeptRespDTO convert03(DeptDO bean);

}
