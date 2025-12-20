<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="我的收藏" showBack :showRight="false"></free-nav-bar>
		<view class="pt-3 px-3" v-for="(item,index) in list" :key="index"
		@longpress="long(item,index)" @click="send(item)">
			<view class="bg-white rounded p-3">
				<text v-if="item.type === 'text'">{{item.data}}</text>
				<free-image v-else-if="item.type === 'image' || item.type === 'emoticon'" :src="item.data"></free-image>
				<video v-else-if="item.type === 'video' " :src="item.data" :poster="item.options.poster" controls style="width: 500rpx;height: 400rpx;"></video>
			</view>
		</view>
		
		<!-- 上拉加载 -->
		<view class="flex align-center justify-center py-5 bg-light"
		v-if="list.length >= 10">
			<text class="text-muted font">{{loadmore}}</text>
		</view>
		
	</view>
</template>

<script>
	import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
	import freeImage from '@/components/free-ui/free-image.vue';
	import $H from '@/common/free-lib/request.js';
	export default {
		components: {
			freeNavBar,
			freeImage
		},
		data() {
			return {
				page:1,
				loadmore:"上拉加载更多", // 没有更多了，加载中...
				list:[],
				type:""
			}
		},
		onLoad(e) {
			if(e.type){
				this.type = e.type
			}
			this.page = 1
			this.getData()
		},
		onPullDownRefresh() {
			this.page = 1
			this.getData().then(res=>{
				uni.stopPullDownRefresh()
			})
		},
		onReachBottom() {
			this.page += 1
			this.getData().catch(err=>{
				this.page -= 1
			})
		},
		methods: {
			send(item){
				if(this.type !== 'send'){
					return
				}
				uni.$emit('sendItem',{
					sendType:"fava",
					...item
				})
				uni.navigateBack({
					delta: 1
				});
			},
			long(item,index){
				uni.showActionSheet({
					itemList: ['删除'],
					success: res => {
						if(res.tapIndex !== 0){
							return
						}
						uni.showModal({
							content: '是否要删除该收藏？',
							success: (res)=> {
								if (res.cancel) {
									return
								}
								$H.post('/fava/destroy',{
									id:item.id
								}).then(res=>{
									uni.showToast({
										title: '删除成功',
										icon: 'none'
									});
									this.list.splice(index,1)
								})
							}
						});
					},
				});
			},
			getData(){
				return new Promise((result,reject)=>{
					$H.get('/fava/'+this.page).then(res=>{
						let list = res.map(item=>{
							item.options = JSON.parse(item.options)
							return item
						})
						this.list = this.page === 1 ? list : [...this.list,...list]
						this.loadmore = this.list.length === this.page * 10 ? '上拉加载更多' : '没有更多了'
						result(res)
					}).catch(err=>{
						reject(err)
					})
				})
			}
		}
	}
</script>

<style>

</style>
