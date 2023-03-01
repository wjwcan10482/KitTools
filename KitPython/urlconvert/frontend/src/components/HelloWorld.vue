<template>
  <Grid :col="1" :border="false">
    <!-- <GridItem style="width: 400px;margin-left: 20px">
      请输入URL eg http://www.baidu.com/1.zip

    </GridItem> -->
    <GridItem>
      <Input v-model="urli" placeholder="" style="width: 400px;margin-left: 20px" />
      <Button type="primary" style="margin-left: 20px" @click="updateurl()">转换</Button>
            <Dropdown style="margin-left: 20px">
        <Button type="primary" @click="downloadurl()" :disabled="disabled">下载<Icon type="ios-arrow-down"></Icon></Button>
        <template #list>
          <DropdownMenu>
            <DropdownItem @click="downloadurl()" :disabled="disabled">直接下载</DropdownItem>
            <DropdownItem @click="docopy()" :disabled="disabled" >复制链接</DropdownItem>
            <DropdownItem @click="deleteurl()" :disabled="disabled" >删除</DropdownItem>
          </DropdownMenu>
        </template>
      </Dropdown>
    </GridItem>
    <!-- <GridItem>
      <Input v-model="urlo" placeholder="" style="width: 400px;margin-left: 20px" disabled />

    </GridItem> -->
    <!-- {{ urlo }} -->
  </Grid>

</template>

<script>
export default {
  name: 'HelloWorld',
  // props: {
  //   disabled: {
  //     default: false
  //   }
  // },
  data() {
    return {
      urli: "请输入URL eg http://www.baidu.com/1.zip",
      urlo: "",
      disabled: true
    }
  },
  methods: {
    updateurl() {
      this.axios.post('urlc', this.urli).then(res => {
        // console.log(res)
        this.urlo = res.data
        this.disabled = false
        console.log("API接口返回数据:"+this.urlo)
      }).catch(err => {
        console.log(err)
      })
    },
    downloadurl() {
      this.disabled = false
      window.location.href = this.urlo;
      console.log("downloadurl: " + this.urlo)
    },
    deleteurl() {
      this.urlo = ""
      this.urli = ""
      this.disabled = true
      console.log("deleteurl")
    },
    docopy() {
      window.location.href = this.urlo;
      this.$copyText(this.urlo).then((res) => {
        console.log("内容已复制到剪切板！，复制的内容为：" + res.text)
      }).catch(err => {
        console.log("抱歉，复制失败！")
      })
    }
  }
}
</script>
