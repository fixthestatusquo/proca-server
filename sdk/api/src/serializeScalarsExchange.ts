
import createSerializeScalarsExchange from 'urql-serialize-scalars-exchange';
import { scalarLocations} from "./queries/scalarLocations";

const serializeScalarsExchange = createSerializeScalarsExchange(
      scalarLocations.inputScalars, scalarLocations.outputScalars,
      {
            Json: {
                  serialize: (v: any) => typeof v === 'string' ? v : JSON.stringify(v),
                  deserialize: (v: string) => JSON.parse(v),
            },
      }
);

export default serializeScalarsExchange;
