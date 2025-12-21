<template>
	<image :src="src" lazy-load :style="imageStyle" :class="imageClass" @tap="$emit('click')" @longpress="$emit('longpress')" @load="loadImage" class="bg-hover-light"></image>
</template>

<script>
	export default {
		props: {
			src: {
				type: String,
				default: ""
			},
			imageClass:{
				type: String,
				default: ""
			},
			maxWidth:{ 
				type: Number,
				default: 500 // rpx
			},
			maxHeight:{
				type: Number,
				default: 350 // rpx
			}
		},
		data() {
			return {
				h: 100,
				w: 100
			}
		},
		computed: {
			imageStyle() {
				return `width:${this.w}px;height:${this.h}px;`
			}
		},
		methods: {
			// 加载图片
			loadImage(e){
				let w = e.detail.width
				let h = e.detail.height
				// // 最大宽度 px
				let maxW = uni.upx2px(this.maxWidth)
				// 最大高度
				let maxH = uni.upx2px(this.maxHeight)
				if (h <= maxH) {
					// 用原来的宽高
					this.w = w <= maxW ? w : maxW
					this.h = h
					this.$emit('load',{
						w:this.w,
						h:this.h
					})
					return;
				}
				this.h = maxH
				let w2 = maxH * (w / h)
				this.w = w2 <= maxW ? w2 : maxW
				this.$emit('load',{
					w:this.w,
					h:this.h
				})
			},
		},
	}
</script>

<style>
</style>
