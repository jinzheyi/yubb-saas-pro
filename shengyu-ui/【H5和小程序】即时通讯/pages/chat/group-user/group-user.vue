<template>
	<view>
		<!-- 导航栏 -->
		<free-nav-bar title="选择" showBack :showRight="false">
		</free-nav-bar>
		<!-- 搜索框 -->
		<view class="p-3 bg-light position-fixed left-0 right-0"
		:style="'top:'+top+'px;'">
			<input type="text" v-model="keyword" placeholder="搜索" class="bg-white rounded" placeholder-class="text-center" style="height: 80rpx;"/>
		</view>
		<view style="height: 140rpx;"></view>
		<!-- 联系人列表 -->
		<view class="px-2 py-1 bg-light">
			<text class="font-sm text-muted">{{keyword ? '搜索结果' :'最近联系人'}}</text>
		</view>
		
		<free-list-item :title="item.name" 
		v-for="(item,index) in allList"
		:key="index" :cover="item.avatar || '/static/images/userpic.png'" showRight :showRightIcon="false" @click="selectItem(item)">
			<view v-if="muliSelect" slot="right" 
			style="width: 40rpx;height: 40rpx;"
			class="border rounded-circle flex align-center justify-center">
				<view v-if="item.checked" style="width: 30rpx;height: 30rpx;"
				class="main-bg-color rounded-circle"></view>
			</view>
		</free-list-item>
		
		<view v-if="keyword !== '' && searchList.length === 0" 
		class="flex align-center justify-center" 
		style="height: 100rpx;">
			<text class="font text-light-muted">暂无搜索结果</text>
		</view>
		
		
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeMainButton from '@/components/free-ui/free-main-button.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import freeAvater from '@/components/free-ui/free-avater.vue';
	import $H from '@/common/free-lib/request.js';
	export default {
		components: {
			freeNavBar,
			freeMainButton,
			freeListItem,
			freeAvater
		},
		data() {
			return {
				keyword:"",
				muliSelect:false,
				top:0,
				list:[],
				group_id:0
			}
		},
		onLoad(e) {
			let res = uni.getSystemInfoSync()
			let statusBarHeight = 0
			// #ifndef MP
			statusBarHeight = res.statusBarHeight
			// #endif
			this.top = statusBarHeight + uni.upx2px(90)
			
			if(e.id){
				this.group_id = e.id
				$H.get('/group_info/'+e.id).then(res=>{
					console.log(res);
					this.list = res.group_users.map(item=>{
						return {
							id:item.user_id,
							name:item.nickname || item.user.nickname || item.user.username,
							avatar:item.user.avatar
						}
					})
				})
			}
		},
		computed: {
			// 最终列表
			allList(){
				return this.keyword==='' ? this.list : this.searchList
			},
			// 搜索结果列表
			searchList(){
				if(this.keyword === ''){
					return []
				}
				return this.list.filter(item=>{
					return item.name.indexOf(this.keyword) !== -1
				})
			},
			// 选中列表
			selectList() {
				return this.list.filter(item=>item.checked) 
			},
			// 选中数量
			selectCount(){
				return this.selectList.length
			}
		},
		methods: {
			// 选中/取消选中 | 发送
			selectItem(item){
				uni.showModal({
					content: '是否要踢出该成员？',
					success: (res)=> {
						if (res.confirm) {
							$H.post('/group/kickoff',{
								id:this.group_id,
								user_id:item.id
							}).then(res=>{
								uni.showToast({
									title: '踢出成功',
									icon: 'none'
								});
								uni.navigateBack({
									delta: 1
								});
							})
						} 
					}
				});
			},
		}
	}
</script>

<style>

</style>
