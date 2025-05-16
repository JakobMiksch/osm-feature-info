<template>
  <main :style="{display: 'flex', width: '100%', height: '100vh'}">
    <div :style="{flex: 1, display: 'flex', flexDirection: 'column'}">
      <select v-model="functionName" @change="triggerRequest()">
        <option v-for="name in functionNameOptions">{{ name }}</option>
      </select>
      <p :style="{
        // @ts-ignore
        color: zoom < minZoomForQuery ? 'red' : 'green'
      }">Zoom Level: {{ zoom?.toFixed(2) }}</p>
      <p>Search Radius: {{ extractedSearchRadius }} meter</p>
      <p v-if="foundFeatures.length > 0">{{ foundFeatures.length }} features found</p>

      <div :style="{flex: 1, overflowY: 'auto'}">
       <OsmInfo :headline="QueryType.ENCLOSING" :results="enclosingFeatures"/>
       <OsmInfo :headline="QueryType.AROUND" :results="aroundFeatures"/>
      </div>
    </div>

    <OlMap id="map" :style="{ flex: 1 }"/>
  </main>
</template>

<script setup lang="ts">
import {  useGeographic } from 'ol/proj'
import { computed, onMounted, ref } from 'vue'
import { useOl, OlMap } from 'vue-ol-comp'
import TileLayer from 'ol/layer/Tile'
import 'ol/ol.css'
import VectorSource from 'ol/source/Vector'
import VectorLayer from 'ol/layer/Vector'

import OsmInfo from './components/OsmInfo.vue'

import {GeoJSON} from "ol/format"
import XYZ from 'ol/source/XYZ'
import { Feature } from 'ol'
import { Point, Polygon } from 'ol/geom'
import axios from 'axios'

useGeographic()

const minZoomForQuery = 14

const { map, onMapClick, extent, zoom } = useOl()
const foundFeatures = ref([])
const functionName = ref("")
const functionNameOptions = ref<string[]>()
const clickedLatitude = ref(NaN)
const clickedLongitude = ref(NaN)

enum QueryType {
  ENCLOSING = 'enclosing',
  AROUND = 'around'
}

// @ts-ignore
const extractedSearchRadius = computed(() => Math.round(10 * Math.pow(1.5, 19 - zoom.value)))

const displayedResult = computed(() => foundFeatures.value.map(feature => {
  const { geometry, properties } = feature
  const { query_type, osm_id, osm_type, tags, geometry_type } = properties
  const url = `https://osm.org/${osm_type}/${osm_id}`
  const hidden = !geometry
  return { url, geometry_type, tags, query_type, osm_id, osm_type, hidden }
}))

const enclosingFeatures = computed(() => displayedResult.value.filter(result => result.query_type === QueryType.ENCLOSING))

const aroundFeatures = computed(()=>displayedResult.value.filter(result => result.query_type === QueryType.AROUND))

const resultVectorSource = new VectorSource()
const pointDataSource = new VectorSource()

const reset = (() => {
  foundFeatures.value = []
  resultVectorSource.clear()
  pointDataSource.clear()
})

const triggerRequest = () => {
  const url = `http://localhost:9000/functions/${functionName.value}/items.json`
  // @ts-ignore
  if (zoom.value < minZoomForQuery) {
    // @ts-ignore
    alert(`Zoom must be below ${minZoomForQuery}`)
    return
  }

  // @ts-ignore
  const [min_lon, min_lat, max_lon, max_lat ] = extent.value
  const latitude = clickedLatitude.value
  const longitude = clickedLongitude.value
  const radius = extractedSearchRadius.value

  axios(url, { params: { latitude, longitude, radius, min_lon, min_lat, max_lon, max_lat  }  })
  .then(response => response.data)
    .then(geojson => {

    const { features } = geojson
    foundFeatures.value = features

    const olFeatures = new GeoJSON().readFeatures(geojson) as any // TODO: fix TS anys

    resultVectorSource.clear()
    resultVectorSource.addFeatures(olFeatures)

    pointDataSource.clear()
    pointDataSource.addFeature(new Feature({geometry: new Point([longitude, latitude])}))

  }).catch(()=>{
    reset()
  })

}

onMapClick((event) => {
  const [lon, lat] = event.coordinate
  clickedLatitude.value = lat
  clickedLongitude.value = lon
  triggerRequest()
})

onMounted(() => {

  axios('http://localhost:9000/functions.json')
    .then(response => response.data)
    .then((functionsInfo) => {
      // @ts-ignore
      functionNameOptions.value = functionsInfo.functions.map(item => item.id) as string[]
      const preferedFunction = 'postgisftw.osm_website_combi'
      if (functionNameOptions.value.includes(preferedFunction)) {
        functionName.value = preferedFunction
      } else {
        functionName.value = functionNameOptions.value[0]
      }
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
        source:  resultVectorSource
      })
    )
    map.value.addLayer(
      new VectorLayer({
        source:  pointDataSource,
        style: {
          'circle-radius': 4,
          'circle-fill-color': 'red'
        }
      }),
    )

  axios('http://localhost:9000/collections/public.geometries.json')
    .then(response => response.data)
    .then(collectionInfo => {
      const bbox = collectionInfo.extent.spatial.bbox[0]

      map.value.getView().fit(bbox)
      map.value.getView().setZoom(minZoomForQuery + 1)

      const coordinates = [
        [
          [bbox[0], bbox[1]], // bottom-left
          [bbox[2], bbox[1]], // bottom-right
          [bbox[2], bbox[3]], // top-right
          [bbox[0], bbox[3]], // top-left
          [bbox[0], bbox[1]]  // close the polygon
        ]
      ];

      const bboxLayer = new VectorLayer({
        source: new VectorSource({ features: [new Feature({ geometry: new Polygon(coordinates) })] }),
        style: {
          'stroke-color': 'gray',
          'stroke-width': 3
        }
      })

      map.value.addLayer(bboxLayer)
    })
})


</script>
