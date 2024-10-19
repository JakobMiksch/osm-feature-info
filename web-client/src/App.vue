
<template>
  <main :style="{display: 'flex', width: '100%', height: '100vh'}">
    <div class="item" :style="{flex: 1, overflowY: 'auto'} ">
      <p v-for="feature in displayedFeatures" :style="{marginLeft: '10px', marginRight: '10px'}">
        {{ feature }}
      </p>
    </div>
    <OlMap  id="map" class="item" :style="{flex: 1}">Div 1</OlMap>
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

useGeographic()

const { map, onMapClick  } = useOl()
const displayedFeatures = ref([])

const vectorSource = new VectorSource()

onMapClick((event)=>{
  const [lon, lat ] = event.coordinate
  const distance = 10
  const url = `http://localhost:9000/functions/postgisftw.osm_feature_info/items.json?latitude=${lat}&longitude=${lon}&distance=${distance}`
  fetch(url)
  .then(async response =>response.json())
  .then(geojson => {

    const {features} = geojson
    displayedFeatures.value = features.map((feature:any )=>feature?.properties ) // TODO: fix TS any

    const olFeatures = new GeoJSON().readFeatures(geojson) as any // TODO: fix TS anys

    vectorSource.clear()
    vectorSource.addFeatures(olFeatures)

  }).catch(()=>{
    displayedFeatures.value = []
    vectorSource.clear()
  })

})

onMounted(() => {

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


  map.value.getView().setCenter([8.755, 53.112])
  map.value.getView().setZoom(15)
})
</script>
