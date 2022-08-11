package cn.iocoder.yudao.module.platform.convert.dept;

import cn.iocoder.yudao.module.platform.api.dept.dto.DeptRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptRespVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface DeptConvert {

    DeptConvert INSTANCE = Mappers.getMapper(DeptConvert.class);

    List<DeptRespVO> convertList(List<PlatformDeptDO> list);

    List<DeptSimpleRespVO> convertList02(List<PlatformDeptDO> list);

    DeptRespVO convert(PlatformDeptDO bean);

    PlatformDeptDO convert(DeptCreateReqVO bean);

    PlatformDeptDO convert(DeptUpdateReqVO bean);

    List<DeptRespDTO> convertList03(List<PlatformDeptDO> list);

    DeptRespDTO convert03(PlatformDeptDO bean);

}
