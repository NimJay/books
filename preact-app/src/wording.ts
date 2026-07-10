/**
 * @file This file implements internationalization.
 */

import { WORDING_MAP } from "./wording-en";

interface WordingMap {
  AboutPageUnderConstruction: string;
  HomePageUnderConstruction: string;
}

function getWording(
  string: keyof WordingMap,
  params: { [key: string]: string } = {}
): string {
  // TODO: We should support other languages in the future.
  let wording = WORDING_MAP[string];
  Object.keys(params).forEach((key) => {
    const regex = new RegExp(`{${key}}`, 'g');
    wording = wording.replace(regex, params[key]);
  });
  return wording;
}

export { getWording }
