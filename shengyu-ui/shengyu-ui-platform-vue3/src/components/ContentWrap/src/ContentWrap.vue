<script lang="ts" setup>
import { propTypes } from '@/utils/propTypes'
import { useDesign } from '@/hooks/web/useDesign'

defineOptions({ name: 'ContentWrap' })

const { getPrefixCls } = useDesign()

const prefixCls = getPrefixCls('content-wrap')
const slots = useSlots()

defineProps({
  title: propTypes.string.def(''),
  message: propTypes.string.def(''),
  variant: propTypes.string.validate((value: string) => ['default', 'filter', 'data', 'sidebar'].includes(value)).def('default'),
  bodyStyle: propTypes.object.def({ padding: '16px 20px' })
})
</script>

<template>
  <ElCard :body-style="bodyStyle" :class="[prefixCls, `${prefixCls}--${variant}`, 'mb-15px']" shadow="never">
    <template v-if="title || slots.header" #header>
      <div class="flex items-center">
        <span v-if="title" class="text-16px font-700">{{ title }}</span>
        <ElTooltip v-if="message" effect="dark" placement="right">
          <template #content>
            <div class="max-w-200px">{{ message }}</div>
          </template>
          <Icon :size="14" class="ml-5px" icon="ep:question-filled" />
        </ElTooltip>
        <div class="flex flex-grow items-center justify-end" :class="title ? 'pl-20px' : ''">
          <slot name="header"></slot>
        </div>
      </div>
    </template>
    <slot></slot>
  </ElCard>
</template>
