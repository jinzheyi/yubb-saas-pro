<template>
  <doc-alert title="官网地址" url="http://www.shengyukj.top/" />

  <ContentWrap>
    <IFrame v-if="!loading" v-loading="loading" :src="src" />
  </ContentWrap>
</template>
<script lang="ts" setup>
import * as ConfigApi from '@/api/infra/config'

defineOptions({ name: 'InfraAdminServer' })

const loading = ref(true) // 是否加载中
const src = ref(import.meta.env.VITE_BASE_URL + '/admin/applications')

/** 初始化 */
onMounted(async () => {
  try {
    // 友情提示：如果访问出现 404 问题：
    // 1）boot 参考 http://shengyukj.top/guide/explain/experience 解决；
    const data = await ConfigApi.getConfigKey('url.spring-boot-admin')
    if (data && data.length > 0) {
      src.value = data
    }
  } finally {
    loading.value = false
  }
})
</script>
