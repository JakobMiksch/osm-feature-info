<template>
  <main :style="{display: 'flex', width: '100%', height: '100vh'}">
    <div :style="{flex: 1, display: 'flex', flexDirection: 'column'}">
      <label for="distance_value">Distance:</label>
      <select v-model="functionName" @change="reset()">
        <option v-for="name in functionNameOptions">{{ name }}</option>
      </select>
      <input id="distance_value" type="number" v-model="distance" @change="reset()" />
      <p v-if="displayedFeatures.length > 0">{{ displayedFeatures.length }} features found</p>

      <div :style="{flex: 1, overflowY: 'auto'}">
        <p v-for="feature in displayedFeatures" :key="feature" :style="{marginLeft: '10px', marginRight: '10px'}">
          {{ feature }}
        </p>
      </div>
    </div>

    <OlMap id="map" :style="{flex: 1}"/>
  </main>
</template>

<script setup lang="ts">
import { fromLonLat, useGeographic } from 'ol/proj'
import { onMounted, ref } from 'vue'
import { useOl, OlMap } from 'vue-ol-comp'
import TileLayer from 'ol/layer/Tile'
import OSM from 'ol/source/OSM'
import 'ol/ol.css'
import VectorSource from 'ol/source/Vector'
import VectorLayer from 'ol/layer/Vector'

import {GeoJSON} from "ol/format"
import XYZ from 'ol/source/XYZ'
import type { Feature } from 'ol'
import type { Geometry } from 'ol/geom'
import { extractRuntimeProps } from 'vue/compiler-sfc'

useGeographic()

const { map, onMapClick  } = useOl()
const displayedFeatures = ref([])
const distance = ref(10)
const functionName = ref("")
const functionNameOptions = ref([])

const vectorSource = new VectorSource()

const reset = (() => {
  displayedFeatures.value = []
  vectorSource.clear()
})

// TODO: fix scrolling issue, so that the text box does not increase the size of the map or viewport or canvas

onMapClick((event)=>{
  const [lon, lat ] = event.coordinate
  const url = `http://localhost:9000/functions/${functionName.value}/items.json?latitude=${lat}&longitude=${lon}&distance=${distance.value}`
  fetch(url)
  .then(async response =>response.json())
  .then(geojson => {

    const {features} = geojson
    displayedFeatures.value = features.map((feature:any )=>feature?.properties ) // TODO: fix TS any

    const olFeatures = new GeoJSON().readFeatures(geojson) as any // TODO: fix TS anys

    vectorSource.clear()
    vectorSource.addFeatures(olFeatures)

  }).catch(()=>{
    reset()
  })

})

onMounted(() => {

  fetch('http://localhost:9000/functions.json').then((response) => response.json()).then((data) => {
    functionNameOptions.value = data.functions.map(item => item.id)
    functionName.value = functionNameOptions.value[0]
  })

  map.value.addLayer(
    new TileLayer({
      source: new XYZ(
        {
          url: "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
        }
      )
    })
    )

    map.value.addLayer(
      new VectorLayer({
        source:  vectorSource
      })
    )


  map.value.getView().setCenter([8.81721, 53.07423])
  map.value.getView().setZoom(15)
})


</script>
