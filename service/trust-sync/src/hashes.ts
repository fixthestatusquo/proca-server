import { Level } from "level";
import { fetchHashes } from "./client";

const db = new Level('./emails.db', { valueEncoding: 'json' });

interface Record {
  email: null | string;
}

interface  Err {
      code: string;
    notFound: boolean;
    status: number;
};
// just for testing
const deleteHash = () => {

h.map(async (j) => {
  console.log("deleting", j)
  await db.del(j);
})
  console.log("Deleted")
}

export const fetch = async () => {

  deleteHash();
  const data = await fetchHashes();

  for (const i in data) {
    try {
     await db.get(data[i]);
    } catch (e) {
      const error = e as Err;
      if (error.notFound) {
        console.log("save hash ", data[i]);
        await db.put<string, Record>(data[i], { email: null }, {});
      } else {
        console.error("Aww, something went wrong", error);
      }
    }
  }
};

