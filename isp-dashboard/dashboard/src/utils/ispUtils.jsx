// Utility function to trim ISP name by taking the part before the first space
  export const trimIspName = (isp) => {
    return isp?.split(' ')[0] || isp;
  };