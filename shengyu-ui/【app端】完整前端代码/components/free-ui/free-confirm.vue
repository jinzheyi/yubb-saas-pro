<template>
	<free-popup ref="confirm" center maskColor transformOrigin="center center">
		<view class="bg-white rounded" style="width: 600rpx;">
			<view class="p-4 flex flex-column">
				<text class="font-md font-weight-bold mb-3">{{title}}</text>
				<slot></slot>
			</view>
			<!-- 底部 -->
			<view style="height: 100rpx;" class="border-top flex align-stretch">
				<view class="flex-1 border-right flex align-center justify-center" @click="cancel">
					<text class="font-md text-muted">取消</text>
				</view>
				<view class="flex-1 flex align-center justify-center"
				@click="confirm">
					<text class="font-md main-text-color">确定</text>
				</view>
			</view>
		</view>
	</free-popup>
</template>

<script>
	import freePopup from '@/components/free-ui/free-popup.vue';
	export default {
		components: {
			freePopup
		},
		props: {
			title: {
				type: String,
				default: "提示"
			},
		},
		data() {
			return {
				callback: false
			}
		},
		methods: {
			// 显示
			show(callback = false){
				this.callback = callback
				this.$refs.confirm.show()
			},
			// 取消
			cancel() {
				this.$refs.confirm.hide()
			},
			// 确定
			confirm(){
				if(typeof this.callback === 'function'){
					this.callback(()=>{
						this.cancel()
					})
				}
			}
		},
	}
</script>

<style>
</style>
