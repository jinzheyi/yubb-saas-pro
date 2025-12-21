<template>
	<view :class="item.istop ? 'bg-light' : 'bg-white'" hover-class="bg-light">
	<div class="flex align-stretch" @click="onClick" @longpress="long">
		<view class="flex align-center justify-center position-relative"
		style="width: 145rpx;">
			<free-avater :src="item.avatar" size="92"></free-avater>
			<free-badge badgeClass="position-absolute"
			badgeStyle="top:15rpx;right:15rpx"
			v-if="item.noreadnum" :value="item.noreadnum"></free-badge>
		</view>
		<view class="flex flex-column border-bottom flex-1 py-3 pr-3 border-light-secondary">
			<view class="flex align-center justify-between mb-1">
				<text class="font-md">{{item.name}}</text>
				<text class="font-sm text-light-muted">{{item.update_time|formatTime}}</text>
			</view>
			<text class="font text-ellipsis text-light-muted">{{item.data}}</text>
		</view>
	</div>
	</view>
</template>

<script>
	import freeBase from "@/common/mixin/free-base.js"
	
	import freeAvater from "@/components/free-ui/free-avater.vue"
	import freeBadge from "@/components/free-ui/free-badge.vue"
	
	import { mapState } from 'vuex'
	
	export default {
		mixins:[freeBase],
		components: {
			freeAvater,
			freeBadge
		},
		props: {
			item: Object,
			index:Number
		},
		computed:{
			...mapState({
				chat:state=>state.user.chat
			})
		},
		methods:{
			onClick(){
				uni.navigateTo({
					url: '/pages/chat/chat/chat?params='+encodeURIComponent(JSON.stringify({
						id:this.item.id,
						name:this.item.name,
						avatar:this.item.avatar,
						chat_type:this.item.chat_type,
					})),
				});
				this.chat.readChatItem(this.item.id,this.item.chat_type)
			},
			long(e){
				let x = 0
				let y = 0
				// #ifdef APP-PLUS-NVUE
				if (Array.isArray(e.changedTouches) && e.changedTouches.length > 0) {
					x = e.changedTouches[0].screenX
					y = e.changedTouches[0].screenY
				}
				// #endif
				// #ifdef H5
				x = e.changedTouches[0].pageX
				y = e.changedTouches[0].pageY
				// #endif
				// #ifdef MP
				x = e.detail.x
				y = e.detail.y
				// #endif
				this.$emit('long',{
					x,
					y,
					index:this.index
				})
			}
		}
	}
</script>

<style>
</style>
