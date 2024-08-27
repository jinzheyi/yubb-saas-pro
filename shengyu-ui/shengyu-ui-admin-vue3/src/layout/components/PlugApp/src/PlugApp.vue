<script lang="ts" name="PlugApp" setup>

const { push } = useRouter()

// 跳转应用市场
const goPluginMarket = () => {
  push({
    name: 'PluginMarket'
  })
}
</script>
<template>
  <div class="message">
    <Icon :size="18" class="cursor-pointer" icon="ep:goods" @click="goPluginMarket" />
  </div>
</template>
<style lang="scss" scoped>

</style>
