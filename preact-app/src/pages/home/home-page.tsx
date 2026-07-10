/**
 * @file This file contains the <HomePage> component.
 */

import { getWording } from "../../wording";
import style from './home-page.module.css';

function HomePage() {
  return (
    <main className={style.HomePage}>
      <p>{getWording("HomePageUnderConstruction")}</p>
    </main>
  );
}

export { HomePage };
