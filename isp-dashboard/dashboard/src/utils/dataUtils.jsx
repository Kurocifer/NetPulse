export const toWAT = (date) => {
  return new Date(date).toLocaleString('en-US', { timeZone: 'Africa/Lagos' });
};

export const formatToWATDateString = (date) => {
  const watDate = toWAT(date);
  return new Date(watDate).toISOString().split('T')[0];
};