<script setup lang="ts">
import HomeClosingSection from "./HomeClosingSection.vue"
import HomeHeroSection from "./HomeHeroSection.vue"
import HomeProofStrip from "./HomeProofStrip.vue"
import HomeStoryRow from "./HomeStoryRow.vue"
import { storySections } from "./content"
</script>

<template>
  <div class="ui-home-page">
    <HomeHeroSection />
    <HomeProofStrip />
    <HomeStoryRow
      v-for="story in storySections"
      :key="story.id"
      :story="story"
    />
    <HomeClosingSection />
  </div>
</template>
