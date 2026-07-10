/**
 * @file This file contains the <AboutPage> component.
 */

import { getWording } from '../../wording';
import style from './about-page.module.css';

export function AboutPage() {
  return (
    <div className={style.AboutPage}>
      <nav>
        <a href='/'>
          &larr; Home page
        </a>
      </nav>
      <main>
        <p>{getWording("AboutPageUnderConstruction")}</p>
      </main>
    </div>
  );
}
