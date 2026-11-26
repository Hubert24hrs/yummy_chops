/**
 * Phone photos are often 4–12 MB. Before uploading, the dashboard shrinks a photo to at most 1200 px on its longest
 * side as a JPEG (a menu shows it far smaller), which keeps uploads fast on mobile data and under the API's 5 MB.
 * Where the browser cannot draw it (or it is already small), the file is sent as it is.
 */
export const PHOTO_TYPES = ["image/jpeg", "image/png", "image/webp"];
const MAX_SIDE = 1200;

export function readAsDataUrl(file: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error("The photo could not be read"));
    reader.readAsDataURL(file);
  });
}

export async function shrinkPhoto(file: File): Promise<string> {
  if (!PHOTO_TYPES.includes(file.type)) throw new Error("Choose a JPEG, PNG or WebP photo");
  const original = await readAsDataUrl(file);
  try {
    const img = await new Promise<HTMLImageElement>((resolve, reject) => {
      const el = new Image();
      el.onload = () => resolve(el);
      el.onerror = () => reject(new Error("not an image"));
      setTimeout(() => reject(new Error("timed out")), 5000); // then the photo is sent as it is
      el.src = original;
    });
    const scale = Math.min(1, MAX_SIDE / Math.max(img.naturalWidth, img.naturalHeight));
    if (!img.naturalWidth || (scale === 1 && file.size < 1_500_000)) return original;
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(img.naturalWidth * scale);
    canvas.height = Math.round(img.naturalHeight * scale);
    const ctx = canvas.getContext("2d");
    if (!ctx) return original;
    ctx.fillStyle = "#fff"; // a transparent PNG becomes white, not black, as a JPEG
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL("image/jpeg", 0.85);
  } catch {
    return original;
  }
}

/** The CSV template a shop fills in (the same as GET /v1/partner/menu-template.csv). */
export const MENU_TEMPLATE =
  "category,name,price,size,brand,description,available,tags\n" +
  "Drinks,Table water,2300,75 cl x 12,Eva,A pack of 12 bottles,yes,water\n" +
  "Rice and pasta,Long grain rice,18500,5 kg,Mama Gold,,yes,rice\n";
