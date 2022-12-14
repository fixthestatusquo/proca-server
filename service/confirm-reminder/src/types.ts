export type LevelError = {
  code: string;
  notFound: boolean;
  status: number;
};

export type RetryRecord = {
  attempts: number;
  retry: string;
};

export type DoneRecord = {
  done: boolean;
}